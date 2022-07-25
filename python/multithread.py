from time import sleep
from random import random, randint
from concurrent.futures import ThreadPoolExecutor
 
# custom task that will sleep for a variable amount of time
def task(name):
    # sleep for less than a second
    sleep(random())
    if randint(1,6) > 5:
        raise ValueError(f'crash: {name}')
    print(f'Done: {name}')
 
# start the thread pool
with ThreadPoolExecutor(2) as executor:
    # submit tasks
    futures = []
    for i in range(6):
        futures.append(executor.submit(task, str(i)))
    # wait for all tasks to complete
    print('Waiting for tasks to complete...')
print('All tasks are done!')
for future in futures:
    if future.exception():
        raise future.exception()
