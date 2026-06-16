FROM alpine:latest

# Install dependencies: bash, dialog (TUI), docker cli, docker-compose plugin, and ttyd
RUN apk add --no-cache bash dialog docker-cli docker-cli-compose ttyd ncurses nano git micro

WORKDIR /app

# Copy the bash script into the container
COPY manager.sh .
RUN chmod +x manager.sh

# Expose the ttyd web port
EXPOSE 8080

# Run ttyd on port 8080, allow writing (-W), and launch the bash script
CMD ["ttyd", "-p", "8080", "-W", "bash", "/app/manager.sh"]
