# Building the binary of the App
FROM golang:1.19 AS build

WORKDIR /go/src/tasky
COPY . .

RUN go mod download

# Ronnie customizations -- Add custom text file 
RUN echo "Hello, Wiz" > /go/src/tasky/assets/wizexercise.txt

# Ronnie customizations - Add -buildvcs=false to avoid vcs stamping
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /go/src/tasky/tasky -buildvcs=false

FROM alpine:3.17.0 AS release

WORKDIR /app
COPY --from=build  /go/src/tasky/tasky .
COPY --from=build  /go/src/tasky/assets ./assets
EXPOSE 8080
ENTRYPOINT ["/app/tasky"]


