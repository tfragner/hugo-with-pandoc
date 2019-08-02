FROM debian:stretch

# Install pygments (for syntax highlighting)
RUN apt-get -qq update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends openssh-client python-pygments git ca-certificates asciidoc curl \
	&& rm -rf /var/lib/apt/lists/*

# Install Git LFS
RUN build_deps="curl ca-certificates" && \
    apt-get update && \
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends git-lfs && \
    git lfs install && \
    rm -r /var/lib/apt/lists/*

# Install TexLive
RUN apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive && apt-get -qq install -y texlive-latex-base texlive-generic-recommended \
    texlive-generic-extra texlive-fonts-recommended  texlive-latex-extra texlive-lang-german texlive-lang-english  \
    texlive-fonts-extra texlive-font-utils texlive-extra-utils texlive-bibtex-extra texlive-xetex texlive-luatex \
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

		# Install Pandoc
		RUN apt-get update && apt-get install ghc cabal-install -y \
		    && cabal update  \
				&& cabal install pandoc-types \
		    && echo export PATH='$PATH:$HOME/.cabal/bin' >> $HOME/.bashrc \
		    && echo export PATH='$PATH:$HOME/.cabal/bin' >> $HOME/.profile \
			&& rm -rf /var/lib/apt/lists/*

		RUN apt-get update && apt-get install wget -y \
			&& wget https://github.com/jgm/pandoc/releases/download/2.3/pandoc-2.3-1-amd64.deb \
			&& dpkg -i pandoc-2.3-1-amd64.deb \
			&& rm pandoc-2.3-1-amd64.deb

# Install pandoc crossref
RUN apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive && apt-get -qq install -y wget \
    && wget https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.3.0/linux-ghc84-pandoc23.tar.gz \
    && tar xvf linux-ghc84-pandoc23.tar.gz \
    && mv pandoc-crossref* /usr/bin/ \
    && rm linux-ghc84-pandoc23.tar.gz \
    && DEBIAN_FRONTEND=noninteractive && apt-get -qq -y remove wget  \
    && DEBIAN_FRONTEND=noninteractive && apt-get -qq -y autoremove \
    && rm -rf /var/lib/apt/lists/*

# Install go
ENV GO_VERSION 1.12.7

RUN curl -sL -o /tmp/go${GO_VERSION}.linux-amd64.tar.gz \
    https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar xvf /tmp/go${GO_VERSION}.linux-amd64.tar.gz && \
    mv go /usr/local && \
    mkdir -p $HOME/work/bin && \
    echo GOPATH=$HOME/work >> ~/.profile && \
    rm /tmp/go${GO_VERSION}.linux-amd64.tar.gz

ENV PATH="/root/.cabal/bin:${PATH}"

# Download and install hugo
ENV HUGO_VERSION v0.55.6

RUN apt-get -qq update \
&& export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin \
&& DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends git build-essential \
&& mkdir $HOME/src && cd $HOME/src && git clone https://github.com/gohugoio/hugo.git && cd hugo \
&& sed -i -- 's/args := \[\]string{"--mathjax"}/args := \[\]string{"--mathjax", "--filter", "pandoc-crossref", "--filter", "pandoc-citeproc", "-M", "linkReferences", "--filter", "pandoc_latex_video.py"}/g' helpers/content.go \
&& go install --tags extended && cp /root/go/bin/hugo /usr/local/bin/hugo \
&& rm -rf /var/lib/apt/lists/* \
&& rm -rf $HOME/src \
&& rm -rf $HOME/work

RUN mkdir /usr/share/blog

WORKDIR /usr/share/blog

# Expose default hugo port
EXPOSE 1313

# By default, serve site
ENV HUGO_BASE_URL http://localhost:1313
CMD   /usr/share/blog/run.sh

# , "--filter", "demoteHeaders.hs"