FROM alpine:latest

# Install dependencies: bash, dialog (TUI), docker cli, docker-compose plugin, ttyd, micro
RUN apk add --no-cache \
    bash \
    dialog \
    docker-cli \
    docker-cli-compose \
    ttyd \
    ncurses \
    micro \
    nano \
    git

WORKDIR /app

# Copy the entire project structure
COPY bin/ ./bin/
COPY lib/ ./lib/
COPY src/ ./src/

# Set executable permissions
RUN chmod +x ./bin/manager ./src/main.sh

# Expose the ttyd web port
EXPOSE 8080

# Run ttyd on port 8080, allow writing (-W), and launch the manager
CMD ["ttyd", "-p", "8080", "-W", "/app/bin/manager"]
