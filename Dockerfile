#=====================================================
# dependencies stage (1/3)
#=====================================================
FROM alpine:3.17 AS deps
RUN apk add --no-cache nodejs npm
WORKDIR /app

# install node dependencies
COPY package.json package-lock.json ./
RUN npm ci

#=====================================================
# builder stage (2/3)
#=====================================================
FROM alpine:3.17 AS builder
RUN apk add --no-cache nodejs npm
WORKDIR /app

# copy the dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# copy the project files
COPY . .

# create next build
RUN npm run build

#=====================================================
# production stage (3/3)
#=====================================================
FROM alpine:3.17 AS runner
RUN apk add --no-cache nodejs
WORKDIR /app

# setup enviroment variables
ENV NODE_ENV=development NEXT_TELEMETRY_DISABLED=1 PORT=3000

# setup usergroup with a user 
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# copy files from previous stages
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
