# Используем базовый образ для сборки
FROM golang:1.21 as builder

# Устанавливаем рабочую директорию
WORKDIR /catgpt

# Копируем файл go.mod и go.sum и скачиваем зависимости
COPY /catgpt/go.mod /catgpt/go.sum ./
RUN go mod download

# Копируем исходный код приложения
COPY /catgpt /catgpt

EXPOSE 8080 9090

# Собираем приложение с CGO_DISABLED
RUN CGO_ENABLED=0 go build -o main.go

# Используем второй базовый образ для рантайма
FROM gcr.io/distroless/static-debian12:latest-amd64

# Копируем бинарный файл из предыдущего образа
COPY --from=builder /catgpt /

# Указываем команду для запуска приложения
CMD ["./main.go"]
