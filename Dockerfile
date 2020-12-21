# Multi Staging Build
FROM python:3.8-buster as builder
# install poetry
RUN pip install -q --upgrade poetry
# clone sytra from repository
RUN git clone -b develop https://github.com/gili-Katagiri/sytra /var/sytra
WORKDIR /var/sytra
# create requirements.txt from pyproject.toml
RUN poetry export -f requirements.txt --output /var/requirements.txt
# install to /var/site-packages:
#     isolate from /usr/local/lib/python3.8/site-packages)
RUN pip install -q -r /var/requirements.txt -t /var/site-packages
# ----------------------------------------


FROM python:3.8-slim-buster
# set environments
ARG STOCKROOTPATH="/root/data"
ENV STOCKROOT $STOCKROOTPATH
# COPY cover for 'git clone ...' and 'pip install ...' without cache
COPY --from=builder /var/sytra /root/sytra
COPY --from=builder /var/site-packages /usr/local/lib/python3.8/site-packages

RUN ln -s /root/sytra/sytra/bin/sytra /usr/local/bin/sytra \
 && sytra init --root-directory $STOCKROOT

WORKDIR /root/sytra
VOLUME $STOCKROOTPATH
CMD ["sytra"]
