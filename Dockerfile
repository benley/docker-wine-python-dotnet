FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

# Need wine 1.7.xx for this all to work, so we'll use the PPA:
RUN dpkg --add-architecture i386 \
 && echo "deb http://ppa.launchpad.net/ubuntu-wine/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/wine.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5A9A06AEF9CB8DB0 \
 && apt-get update \
 && apt-get install --no-install-recommends -qfy wine1.7 winetricks \
 && apt-get clean
RUN apt-get -qfy install ca-certificates

RUN useradd -d /app -m app
USER app
ENV HOME /app
RUN mkdir -p /app/src
RUN mkdir -p /app/.profile.d
WORKDIR /app/src

ENV WINEARCH win32
# Silence all the "fixme: blah blah blah" messages from wine
ENV WINEDEBUG fixme-all

# Install the .net 4.0 runtime (not actually required for python!)
RUN wineboot \
 && winetricks -q dotnet40 \
 && while pgrep wineserver >/dev/null; do echo "Waiting for wineserver"; sleep 1; done \
 && rm -rf $HOME/.cache/winetricks

# Install Python itself, tweaked very slightly so SSL works.
RUN wget -nv https://www.python.org/ftp/python/2.7.9/python-2.7.9.msi \
 && wine msiexec /qn /a python-2.7.9.msi \
 && rm python-2.7.9.msi \
 && sed -i 's/_windows_cert_stores = .*/_windows_cert_stores = ("ROOT",)/' "$HOME/.wine/drive_c/Python27/Lib/ssl.py" \
 && mkdir -p /app/bin \
 && echo 'wine '\''C:\Python27\python.exe'\'' "$@"' > /app/bin/python \
 && echo 'wine '\''C:\Python27\Scripts\easy_install.exe'\'' "$@"' > /app/bin/easy_install \
 && echo 'wine '\''C:\Python27\Scripts\pip.exe'\'' "$@"' > /app/bin/pip \
 && chmod +x /app/bin/* \
 && wget https://bootstrap.pypa.io/ez_setup.py -O - | /app/bin/python \
 && /app/bin/easy_install pip \
 && echo 'assoc .py=PythonScript' | wine cmd \
 && echo 'ftype PythonScript=c:\Python27\python.exe "%1" %*' | wine cmd \
 && while pgrep wineserver >/dev/null; do echo "Waiting for wineserver"; sleep 1; done \
 && rm -rf /tmp/.wine-*

ENV PATH ${HOME}/bin:${PATH}

ONBUILD COPY . /app/src
ONBUILD RUN test -e requirements.txt && pip install -r requirements.txt \
 && while pgrep wineserver >/dev/null; do echo "Waiting for wineserver"; sleep 1; done \
 && rm -rf /tmp/.wine-*
