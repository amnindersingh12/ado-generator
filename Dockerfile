# syntax=docker/dockerfile:1
# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.7
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Set working directory for the Rails app
WORKDIR /rails

# Install required base packages and dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl libjemalloc2 libvips sqlite3 build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set environment variables for Rails production
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    SECRET_KEY_BASE_DUMMY=1

# Install application gems, precompile boot files, and cleanup
FROM base AS build

# Install the required gems and clean up
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap and assets for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production
RUN ./bin/rails assets:precompile

# Final image for the app (runtime stage)
FROM base

# Copy the gems and application code from the build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create a non-root user for security reasons
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER 1000:1000

# Entry point for database setup (if needed)
ENTRYPOINT ["/bin/bash", "/rails/bin/docker-entrypoint"]

# Expose port 3000
EXPOSE 3000

# Command to start the server, can be overridden at runtime
CMD ["./bin/thrust", "./bin/rails", "server"]
