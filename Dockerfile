# syntax=docker/dockerfile:1

# Stage 1: Base image with core Ruby and minimal runtime dependencies
ARG RUBY_VERSION=3.2.7
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Set working directory for the Rails app
WORKDIR /rails

# Install core runtime packages
# - curl: For making HTTP requests (e.g., health checks, external APIs)
# - libjemalloc2: For memory optimization in Ruby
# - libvips: Common image processing library for Active Storage variants
# - sqlite3: If you decide to stick with SQLite for simple cases
# - git: Might be needed for some gems that depend on git
# - libyaml-dev: Required for psych gem (YAML parser)
# - pkg-config: Often a dependency for compiling other native extensions
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl libjemalloc2 libvips sqlite3 git libyaml-dev pkg-config \
    && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set environment variables for Rails production
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Stage 2: Build image (for installing gems and precompiling assets)
FROM base AS build

# Install build-time packages (needed only for compiling Ruby gems)
# - build-essential: Compilers (gcc, g++, make) for native gem extensions
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy Gemfile and Gemfile.lock first to leverage Docker cache
COPY Gemfile Gemfile.lock ./

# Install application gems
# rm -rf commands reduce image size by cleaning up build artifacts
# bootsnap precompile improves Rails boot time
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy the rest of the application code
COPY . .

# Precompile bootsnap cache for app/ lib/ for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets for production
# SECRET_KEY_BASE_DUMMY allows asset precompilation without a real master key
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Stage 3: Final image (runtime)
FROM base

# Create a non-root user for security reasons
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

# Copy the bundled gems and application code from the build stage
COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

# Set the user for subsequent commands
USER 1000:1000

# Copy and set permissions for the custom entrypoint script
COPY --chown=rails:rails bin/docker-entrypoint /rails/bin/docker-entrypoint
RUN chmod +x /rails/bin/docker-entrypoint

# Define the entry point for the container
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Expose port 3000 where the Rails server will run
EXPOSE 3000

# Default command to start the Rails server
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]