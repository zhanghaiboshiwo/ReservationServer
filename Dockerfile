FROM mcr.microsoft.com/dotnet/aspnet:5.0-alpine AS base

RUN apk add libgdiplus --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted && \
    apk add terminus-font && \
    apk add --no-cache icu-libs
# https://www.abhith.net/blog/docker-sql-error-on-aspnet-core-alpine/
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT false
ENV ASPNETCORE_FORWARDEDHEADERS_ENABLED=true

EXPOSE 80
LABEL Maintainer="WeihanLi"

FROM mcr.microsoft.com/dotnet/sdk:5.0-alpine AS build-env
WORKDIR /src

# Copy csproj and restore as distinct layers
# https://andrewlock.net/optimising-asp-net-core-apps-in-docker-avoiding-manually-copying-csproj-files-part-2/
COPY */*.csproj ./
RUN for file in $(ls *.csproj); do mkdir -p ${file%.*}/ && mv $file ${file%.*}/; done

WORKDIR /src/OpenReservation
RUN dotnet restore

# copy everything and build
COPY . .
RUN dotnet publish -c Release -o out OpenReservation/OpenReservation.csproj

# build runtime image
FROM base AS final

WORKDIR /app
COPY --from=build-env /src/OpenReservation/out .

ENTRYPOINT ["dotnet", "OpenReservation.dll"]
