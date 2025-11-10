# Multi-stage Dockerfile for Figma MCP Server
# Stage 1: Builder - Install dependencies and build the application
FROM node:18-alpine AS builder

# Install pnpm globally
RUN npm install -g pnpm@10.10.0

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install ALL dependencies (including devDependencies for building)
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build the application
RUN pnpm build

# Remove dev dependencies to reduce size
RUN pnpm prune --prod

# Stage 2: Production - Create minimal runtime image
FROM node:18-alpine AS production

# Install pnpm (only needed if we want to use pnpm commands)
RUN npm install -g pnpm@10.10.0

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy package files
COPY --chown=nodejs:nodejs package.json ./

# Copy production dependencies from builder
COPY --chown=nodejs:nodejs --from=builder /app/node_modules ./node_modules

# Copy built application from builder
COPY --chown=nodejs:nodejs --from=builder /app/dist ./dist

# Create logs directory with proper permissions
RUN mkdir -p /app/logs && chown -R nodejs:nodejs /app/logs

# Switch to non-root user
USER nodejs

# Expose port (default 3333)
EXPOSE 3333

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3333/mcp', (res) => { process.exit(res.statusCode === 200 ? 0 : 1); }).on('error', () => process.exit(1));"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the server in HTTP mode
CMD ["node", "dist/bin.js"]

