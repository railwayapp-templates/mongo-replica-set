# Base image
FROM mongo:latest

# Install curl
RUN apt-get update && apt-get install -y curl

# Copy the initiation script into the container
COPY initiate-replica-set.sh /initiate-replica-set.sh

# Make the script executable
RUN chmod +x /initiate-replica-set.sh

# Run the script
CMD ["/initiate-replica-set.sh"]
