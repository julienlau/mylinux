import logging
from logging.handlers import RotatingFileHandler
import argparse
import glob
import requests
import time
import numpy as np
import concurrent.futures
from datetime import datetime

# Define the start time at the beginning of your script
start_time_str = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
log_filename = f"log_{start_time_str}.txt"

# Setup logger with multiple handlers
def setup_logging():
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    # Format for our loglines
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    
    # Setup STDOUT handler
    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)
    logger.addHandler(stream_handler)
    
    # Setup File handler
    file_handler = RotatingFileHandler(log_filename, maxBytes=5000000, backupCount=5)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

# Ensure to call this function at the beginning of your main function
setup_logging()

def perform_ocr(file_path, ocr_url, timeout, max_redirects, headers, cert):
    logging.info(f"Starting OCR request for file: {file_path}")
    with open(file_path, 'rb') as file:
        files = {'file': (file_path, file)}
        session = requests.Session()
        session.max_redirects = max_redirects
        start_time = time.time()
        response = session.post(ocr_url, files=files, timeout=timeout, headers=headers, cert=cert, allow_redirects=True)
        total_time = time.time() - start_time
        if response.status_code == 200:
            redirect_time = total_time - response.elapsed.total_seconds()
            logging.info(f"Completed OCR request for file: {file_path} in {total_time:.2f}s (including redirects)")
            return file_path, total_time, redirect_time
        else:
            logging.error(f"OCR request for file: {file_path} failed with status code {response.status_code}")
            return file_path, None, None

def perform_ocr_concurrently(files, ocr_url, timeout, max_redirects, max_workers, headers, cert):
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_file = {executor.submit(perform_ocr, file, ocr_url, timeout, max_redirects, headers, cert): file for file in files}
        results = {}
        for future in concurrent.futures.as_completed(future_to_file):
            file_path, total_time, redirect_time = future.result()
            if total_time is not None:
                if ocr_url not in results:
                    results[ocr_url] = {'timings': [], 'redirect_timings': []}
                results[ocr_url]['timings'].append(total_time)
                results[ocr_url]['redirect_timings'].append(redirect_time)
        return results

def calculate_statistics(results):
    for ocr_url, data in results.items():
        timings = data['timings']
        redirect_timings = data['redirect_timings']
        data.update({
            'average': np.mean(timings),
            'std_dev': np.std(timings),
            'min_time': np.min(timings),
            'max_time': np.max(timings),
            'avg_redirect_time': np.mean(redirect_timings)
        })
    return results

def parse_arguments():
    parser = argparse.ArgumentParser(description="Benchmark OCR solutions with concurrency and authentication support")
    parser.add_argument("--directory", required=True, help="Path to the directory containing PDF files")
    parser.add_argument("--repeats", type=int, default=5, help="Number of times to repeat OCR processing for each file")
    parser.add_argument("--timeout", type=int, default=60, help="HTTP request timeout in seconds")
    parser.add_argument("--max-redirects", type=int, default=10, help="Maximum number of redirects to follow for an OCR request")
    parser.add_argument("--output-file", required=True, help="Output file name to write the Markdown table")
    parser.add_argument("--base-url", required=True, help="Base URL of the OCR service")
    parser.add_argument("--concurrency", type=int, default=1, help="Number of concurrent OCR queries to perform")
    parser.add_argument("--bearer-token", help="Bearer token for OCR requests")
    parser.add_argument("--cert-file", default="client.crt", help="Client certificate file")
    parser.add_argument("--key-file", default="client.key", help="Client key file")
    return parser.parse_args()

def main():
    start_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    args = parse_arguments()
    files = glob.glob(f'{args.directory}/*.pdf') * args.repeats
    ocr_url = args.base_url
    headers = {"Accept": "application/json"}
    cert = (args.cert_file, args.key_file)

    if args.bearer_token:
        headers["Authorization"] = f"Bearer {args.bearer_token}"

    if args.concurrency > 1:
        results = perform_ocr_concurrently(files, ocr_url, args.timeout, args.max_redirects, args.concurrency, headers, cert)
    else:
        results = {}
        for file in files:
            _, total_time, redirect_time = perform_ocr(file, ocr_url, args.timeout, args.max_redirects, headers, cert)
            if ocr_url not in results:
                results[ocr_url] = {'timings': [], 'redirect_timings': []}
            results[ocr_url]['timings'].append(total_time)
            results[ocr_url]['redirect_timings'].append(redirect_time)
    results = calculate_statistics(results)

    # Output results
    with open(args.output_file, 'w') as f:
        f.write("| Start Time | Concurrency | OCR URL | Average Time (s) | Std Dev (s) | Minimum Time (s) | Maximum Time (s) | Avg Redirect Time (s) |\n")
        f.write("|------------|-------------|---------|------------------|-------------|------------------|------------------|-----------------------|\n")
        for ocr_url, data in results.items():
            f.write(f"| {start_time} | {args.concurrency} | {ocr_url} | {data['average']:.2f} | {data['std_dev']:.2f} | {data['min_time']:.2f} | {data['max_time']:.2f} | {data['avg_redirect_time']:.2f} |\n")

if __name__ == "__main__":
    main()

