FROM mambaorg/micromamba:2.2.0

USER root

# install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
      cmake \
      build-essential \
    && rm -rf /var/lib/apt /var/lib/dpkg /var/lib/cache /var/lib/log

# copy source code
COPY --chown=$MAMBA_USER:$MAMBA_USER . /opt/STRONG/

USER $MAMBA_USER

# install SPAdes
RUN /opt/STRONG/SPAdes/assembler && ./build_cog_tools.sh

# install conda env
RUN micromamba install --yes --file /opt/STRONG/conda_env.yaml && \
    micromamba clean --all --yes

ARG MAMBA_DOCKERFILE_ACTIVATE=1

# install BayesPaths and DESMAN
RUN cd /opt/STRONG/BayesPaths && python ./setup.py install && \
    cd /opt/STRONG/DESMAN && python ./setup.py install

# fix
RUN ln -fs $CONDA_PREFIX/lib/R/modules/lapack.so $CONDA_PREFIX/lib/R/modules/libRlapack.so && \
    PATH_concoctR=$(which concoct_refine) && \
    sed -i 's/values/to_numpy/g' $PATH_concoctR && \
    sed -i 's/as_matrix/to_numpy/g' $PATH_concoctR && \
    sed -i 's/int(NK), args.seed, args.threads)/ int(NK), args.seed, args.threads, 500)/g' $PATH_concoctR

# test
RUN python /opt/STRONG/SnakeNest/scripts/check_on_dependencies.py
