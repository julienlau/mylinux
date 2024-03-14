import argparse
import glob
import logging
import requests
import time
import numpy as np

# Setup logger
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def perform_ocr(file_path, ocr_url, timeout, max_redirects):
    with open(file_path, 'rb') as file:
        files = {'file': (file_path, file)}
        session = requests.Session()
        session.max_redirects = max_redirects
        start_time = time.time()
        response = session.post(ocr_url, files=files, timeout=timeout, allow_redirects=True)
        total_time = time.time() - start_time
        if response.status_code == 200:
            # Assuming 'elapsed' includes total time minus time spent in redirects
            redirect_time = total_time - response.elapsed.total_seconds()
            return total_time, redirect_time
        else:
            raise Exception(f"OCR request failed with status {response.status_code}")

def prewarm_ocr(ocr_url, timeout):
    # Implement prewarming logic here if needed
    pass

def benchmark_ocr(files, ocr_urls, repeats, prewarm, timeout, max_redirects):
    results = {}
    for ocr_url in ocr_urls:
        logging.info(f"Testing OCR at {ocr_url}")
        if prewarm:
            prewarm_ocr(ocr_url, timeout)
        for file_path in files:
            timings = []
            redirect_timings = []
            for _ in range(repeats):
                try:
                    total_time, redirect_time = perform_ocr(file_path, ocr_url, timeout, max_redirects)
                    timings.append(total_time)
                    redirect_timings.append(redirect_time)
                except Exception as e:
                    logging.error(f"Error during OCR processing: {e}")
            results[(ocr_url, file_path)] = {
                'average': np.mean(timings),
                'std_dev': np.std(timings),
                'min_time': np.min(timings),
                'max_time': np.max(timings),
                'avg_redirect_time': np.mean(redirect_timings)
            }
    return results

def parse_arguments():
    parser = argparse.ArgumentParser(description="Benchmark OCR solutions")
    parser.add_argument("--directory", required=True, help="Path to the directory containing PDF files")
    parser.add_argument("--repeats", type=int, default=5, help="Number of times to repeat OCR processing for each file")
    parser.add_argument("--timeout", type=int, default=60, help="HTTP request timeout in seconds")
    parser.add_argument("--max-redirects", type=int, default=10, help="Maximum number of redirects to follow for an OCR request")
    return parser.parse_args()

def main():
    args = parse_arguments()
    files = glob.glob(f'{args.directory}/*.pdf')
    ocr_urls = [
        # Add OCR URLs here
    ]
    results = benchmark_ocr(files, ocr_urls, args.repeats, prewarm=True, timeout=args.timeout, max_redirects=args.max_redirects)

    # Print results in Markdown format
    print("| Input Filename | OCR URL | Average Time (s) | Std Dev (s) | Minimum Time (s) | Maximum Time (s) | Avg Redirect Time (s) |")
    print("|----------------|---------|------------------|-------------|------------------|------------------|-----------------------|")
    for key, value in results.items():
        ocr_url, file_path = key
        filename = file_path.split('/')[-1]
        print(f"| {filename} | {ocr_url} | {value['average']:.2f} | {value['std_dev']:.2f} | {value['min_time']:.2f} | {value['max_time']:.2f} | {value['avg_redirect_time']:.2f} |")

if __name__ == "__main__":
    main()

