FROM golang:alpine as builder

WORKDIR /build
COPY go.mod .
COPY go.sum .
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o fwdr .

WORKDIR /dist
RUN cp /build/fwdr .
FROM scratch
COPY --from=builder /dist/fwdr /app/
COPY configuration.json /app/
WORKDIR /app
CMD ["./fwdr"]