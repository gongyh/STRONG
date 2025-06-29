FROM mambaorg/micromamba:2.2.0

USER root
# copy source code
COPY --chown=$MAMBA_USER:$MAMBA_USER . /opt/STRONG/

USER $MAMBA_USER
# install conda env
RUN micromamba install --yes --name base --file /opt/STRONG/conda_env.yaml && \
    micromamba clean --all --yes

USER root
# install system dependencies for spades
RUN apt-get update && apt-get install -y --no-install-recommends \
      cmake \
      build-essential \
      zlib1g-dev \
      libssl-dev \
      openssl \
      libbz2-dev \
    && rm -rf /var/lib/apt /var/lib/dpkg /var/lib/cache /var/lib/log

USER $MAMBA_USER

# install SPAdes
RUN cd /opt/STRONG/SPAdes/assembler && ./build_cog_tools.sh

ARG MAMBA_DOCKERFILE_ACTIVATE=1

# install BayesPaths and DESMAN
RUN cd /opt/STRONG/BayesPaths && sed -i 's/sklearn/scikit-learn/g' setup.py && pip install . && \
    cd /opt/STRONG/DESMAN && pip install .

# fix
RUN ln -fs $CONDA_PREFIX/lib/R/modules/lapack.so $CONDA_PREFIX/lib/R/modules/libRlapack.so && \
    PATH_concoctR=$(which concoct_refine) && \
    sed -i 's/values/to_numpy/g' $PATH_concoctR && \
    sed -i 's/as_matrix/to_numpy/g' $PATH_concoctR && \
    sed -i 's/int(NK), args.seed, args.threads)/ int(NK), args.seed, args.threads, 500)/g' $PATH_concoctR && \
    sed -i 's/memG=400/mem_mb=204800/g' /opt/STRONG/SnakeNest/Results.snake && \
    sed -i 's/memG=400/mem_mb=204800/g' /opt/STRONG/SnakeNest/ko_profiles.snake

# test
RUN python /opt/STRONG/SnakeNest/scripts/check_on_dependencies.py
