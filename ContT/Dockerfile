# Используем образ .NET SDK для сборки приложения
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Копируем файлы проекта и восстанавливаем зависимости
COPY . ./
RUN dotnet restore

# Сборка проекта
RUN dotnet publish -c Release -o /out

# Используем образ .NET Runtime для запуска приложения
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /out .

# Задаем порт, который будет использоваться контейнером
EXPOSE 8080

# Запускаем приложение
ENTRYPOINT ["dotnet", "ContT.dll"]
