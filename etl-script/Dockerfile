FROM public.ecr.aws/lambda/python:3.11
COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip install --upgrade pip && \
    pip install -r requirements.txt --only-binary=:all:
COPY main.py ${LAMBDA_TASK_ROOT}
CMD [ "main.lambda_handler" ]