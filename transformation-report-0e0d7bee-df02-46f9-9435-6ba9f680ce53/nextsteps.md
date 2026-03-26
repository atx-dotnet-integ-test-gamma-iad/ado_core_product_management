# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment.

## 1. Review the Transformed Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to Windows-specific assemblies (e.g., `System.Data`, `System.Configuration`) have been replaced with the appropriate NuGet packages or framework-provided equivalents.
- No `<HintPath>` entries point to absolute paths or paths that only exist on the original build machine.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to current stable versions via:

```bash
dotnet list package --outdated
dotnet add package <PackageName> --version <NewVersion>
```

## 3. Build the Solution

Perform a clean build to confirm there are no errors in the restored state:

```bash
dotnet build --configuration Release
```

Review any warnings that surface during the build. While warnings do not block compilation, they can indicate deprecated APIs or compatibility concerns that should be addressed before deployment.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during transformation:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime, particularly in areas such as:

- `System.Data` ADO.NET provider behavior
- Connection string formats
- Exception types and messages
- Culture and encoding defaults

## 5. Validate ADO.NET Connectivity

Since the project is named `AdoCore`, it likely contains data access logic. Confirm the following at runtime:

- The correct database provider NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` for SQL Server, `Npgsql` for PostgreSQL, `MySql.Data` for MySQL).
- Connection strings are being read from the correct configuration source. In cross-platform .NET, `App.config` is not used by default; connection strings should be sourced from `appsettings.json` or environment variables via `Microsoft.Extensions.Configuration`.
- Any use of `ConfigurationManager` has been replaced with the `Microsoft.Extensions.Configuration` API, or the `System.Configuration.ConfigurationManager` NuGet package has been added if a direct replacement is not yet feasible.

## 6. Test on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) to surface any platform-specific issues:

```bash
dotnet run --configuration Release
```

Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity of file and directory names on Linux
- Any P/Invoke or COM interop calls that will not function outside of Windows

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your target platform (e.g., `win-x64`, `osx-x64`, `linux-arm64`). Use `--self-contained true` if you need to deploy without requiring the .NET runtime to be pre-installed on the target machine.

Review the contents of the `publish` output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.