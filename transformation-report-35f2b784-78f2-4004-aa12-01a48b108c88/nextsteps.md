# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Run the application and exercise its primary code paths:

```bash
dotnet run --configuration Release --project AdoCore.csproj
```

Pay particular attention to:
- Database connectivity and ADO.NET operations, since `AdoCore` suggests data access logic.
- Any platform-specific APIs that may have been available on Windows but behave differently or are unavailable on Linux/macOS.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with your target framework. Use the following command to list outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 6. Validate Platform-Specific Behavior

Since this is a cross-platform migration, test the application on each intended target operating system (Windows, Linux, macOS) to identify any OS-specific runtime differences, particularly around:
- File path separators
- Registry access (not available on non-Windows platforms)
- Windows-only authentication mechanisms (e.g., Windows Authentication in ADO.NET connections)

## 7. Review Connection Strings and Configuration

If `AdoCore` manages database connections, verify that connection strings in configuration files (`appsettings.json`, `app.config`, etc.) are valid in the new environment and do not rely on Windows-only data providers.

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required files are present.