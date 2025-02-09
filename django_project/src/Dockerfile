#FROM python:3.5-stretch
# See https://github.com/thinkWhere/GDAL-Docker
# WARN: We should review/copy this image before going to prod
FROM thinkwhere/gdal-python:3.6-ubuntu

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN mkdir /code
WORKDIR /code

COPY wait-for-it.sh /
COPY start.sh /
COPY install-database.sh /code/
COPY REQUIREMENTS.txt  /code/
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server postgresql-client \
&& rm -rf /var/lib/apt/lists/* \
&& pip3 install --no-cache-dir --upgrade pip \
&& pip3 install --no-cache-dir --upgrade setuptools \
&& pip3 install --no-cache-dir GDAL \
&& pip3 install --no-cache-dir -r REQUIREMENTS.txt \
&& chmod +x /wait-for-it.sh \
&& chmod +x /start.sh \
&& chmod +x /code/install-database.sh \
&& ln -s /usr/lib/x86_64-linux-gnu/libgeos_c.so.1 /usr/lib \
&& ln -s /usr/lib/x86_64-linux-gnu/libgeos_c.so /usr/lib \
&& echo "root:Docker!" | chpasswd
COPY . /code/

COPY sshd_config /etc/ssh/

EXPOSE 8000 2222
CMD ["/start.sh"]
