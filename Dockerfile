FROM debian:stretch

# Install pygments (for syntax highlighting) 
RUN apt-get -qq update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends openssh-client python-pygments git ca-certificates asciidoc curl \
	&& rm -rf /var/lib/apt/lists/*

# Install TexLive
RUN apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive && apt-get -qq install -y texlive-latex-base texlive-generic-recommended \
    texlive-generic-extra texlive-fonts-recommended  texlive-latex-extra texlive-lang-german texlive-lang-english  \
    texlive-fonts-extra texlive-font-utils texlive-extra-utils texlive-bibtex-extra texlive-xetex texlive-luatex \
    && rm -rf /var/lib/apt/lists/*

# Install Pandoc
RUN apt-get update && apt-get install ghc cabal-install -y \
    && cabal update \
    && echo export PATH='$HOME/.cabal/bin:$PATH' >> $HOME/.bashrc \
    && echo export PATH='$HOME/.cabal/bin:$PATH' >> $HOME/.profile \
	&& rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install happy zlib1g-dev -y \
    && cabal install happy \
    && cabal install pandoc \
	&& rm -rf /var/lib/apt/lists/*

# Install Python
RUN apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive && apt-get install -y build-essential libssl-dev wget zlib1g zlib1g-dev \
    && wget https://www.python.org/ftp/python/3.6.6/Python-3.6.6.tgz \
    && tar xvf Python-3.6.6.tgz \
    && cd Python-3.6.6 \
    && ./configure --enable-optimizations \
    && make -j8 \
    && make altinstall \
    && cd .. && rm -rf Python-3.6.6 && rm Python-3.6.6.tgz \
    && DEBIAN_FRONTEND=noninteractive && apt-get -qq -y remove build-essential  \
    && DEBIAN_FRONTEND=noninteractive && apt-get -qq -y autoremove \
    && rm -rf /var/lib/apt/lists/*

# Install pandoc crossref
RUN apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive && apt-get -qq install -y wget \
    && wget https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.2.1/linux-ghc84-pandoc22.tar.gz \
    && tar xvf linux-ghc84-pandoc22.tar.gz \
    && mv pandoc-crossref* /usr/bin/ \
    && rm linux-ghc84-pandoc22.tar.gz \
    && DEBIAN_FRONTEND=noninteractive && apt-get -qq -y remove wget  \
    && DEBIAN_FRONTEND=noninteractive && apt-get -qq -y autoremove \
    && rm -rf /var/lib/apt/lists/*
    
# Install go
ENV GO_VERSION 1.11

RUN curl -sL -o /tmp/go${GO_VERSION}.linux-amd64.tar.gz \
    https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar xvf /tmp/go${GO_VERSION}.linux-amd64.tar.gz && \
    mv go /usr/local && \
    mkdir -p $HOME/work/bin && \
    echo GOPATH=$HOME/work >> ~/.profile && \
    rm /tmp/go${GO_VERSION}.linux-amd64.tar.gz

ENV PATH="/root/.cabal/bin:${PATH}"

# Download and install hugo
ENV HUGO_VERSION v0.48

RUN apt-get -qq update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends git \
	&& export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin \
	&& git clone https://github.com/gohugoio/hugo \
	&& cd hugo && git checkout ${HUGO_VERSION} \
	&& mkdir -p src/github.com/gohugoio \
    && ln -sf $(pwd) src/github.com/gohugoio/hugo \
    && export GOPATH=$(pwd) \
    && export GOBIN=/usr/local/bin \
    && rm $GOPATH/go.mod \
    && go get \
    && sed -i -- 's/args := \[\]string{"--mathjax"}/args := \[\]string{"--mathjax", "--filter", "pandoc-crossref", "--filter", "pandoc-citeproc", "-M", "linkReferences", "--filter", "pandoc_latex_video.py", "--number-sections"}/g' helpers/content.go \
    && go build -o hugo main.go \
    && rm /usr/local/bin/hugo \
    && cp hugo /usr/local/bin/hugo \
    && cd .. && rm -rf hugo \
	&& rm -rf /var/lib/apt/lists/*

RUN cabal install pandoc-citeproc

RUN mkdir /usr/share/blog

WORKDIR /usr/share/blog

# Expose default hugo port
EXPOSE 1313

# By default, serve site
ENV HUGO_BASE_URL http://localhost:1313
CMD hugo server -b ${HUGO_BASE_URL} --bind=0.0.0.0
