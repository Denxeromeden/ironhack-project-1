# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY Worker.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app/publish

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/runtime:10.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish ./

ENV DB_HOST=db
ENV DB_USERNAME=postgres
ENV DB_NAME=postgres
ENV REDIS_HOST=redis

# app, the unprivileged user the .NET image ships
USER 1654

# Define the entry point
ENTRYPOINT ["dotnet", "Worker.dll"]
