# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay particular attention to the following areas:

- **`System.Configuration`**: If the project previously used `ConfigurationManager`, ensure you have added the `System.Configuration.ConfigurationManager` NuGet package and migrated any `app.config` settings as needed.
- **ADO.NET Providers**: Since the project is named `AdoCore`, verify that the database provider (e.g., `System.Data.SqlClient` or `Microsoft.Data.SqlClient`) is explicitly referenced and functional on the target platform.
- **Platform-Specific APIs**: Any Windows-only APIs (e.g., registry access, COM interop) will fail at runtime on non-Windows platforms even if they compile successfully.

## 5. Validate Database Connectivity

Given the ADO-related nature of this project, manually test all database connection paths:

- Confirm connection strings are correctly sourced (e.g., from `appsettings.json` rather than `app.config` if applicable).
- Execute representative queries against a test database to confirm data access works as expected.

## 6. Review NuGet Package Compatibility

Run the following command to check for any outdated or potentially incompatible packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that were migrated from older `.NET Framework`-era versions.

## 7. Test on Target Platform

If cross-platform support (Linux/macOS) is a goal, run the application on the intended non-Windows platform to surface any remaining platform-specific issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Use `--self-contained true` if you require the .NET runtime to be bundled with the output.