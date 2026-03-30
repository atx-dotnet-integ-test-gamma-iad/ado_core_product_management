# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in cross-platform .NET compared to .NET Framework. Review the following areas manually:

- **`System.Data`** and ADO.NET usage — confirm that any database providers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are the correct cross-platform variants.
- **`System.Configuration`** — this is not available by default in cross-platform .NET. If configuration is used, ensure a migration to `Microsoft.Extensions.Configuration` has been completed.
- **Registry access** — `Microsoft.Win32.Registry` is Windows-only. If used, verify it is either removed or guarded with a runtime OS check.

## 5. Run Existing Tests

If a test project exists in the solution, execute the tests to validate runtime behavior:

```bash
dotnet test --configuration Release
```

Review any failing tests and address runtime regressions that may not have surfaced as build errors.

## 6. Perform Runtime Smoke Testing

Run the application locally and exercise its primary functionality. Pay particular attention to:

- Database connectivity and query execution
- Any file I/O operations that may rely on Windows-specific path assumptions
- Any reflection-based code that may behave differently on cross-platform .NET

## 7. Validate on a Non-Windows Platform (if applicable)

If cross-platform support is a goal, test the application on Linux or macOS:

```bash
dotnet run --configuration Release
```

Address any `PlatformNotSupportedException` or OS-specific failures that appear at runtime.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent (requires .NET runtime on target machine)
dotnet publish --configuration Release

# Self-contained for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Review the output in the `publish` folder before deploying to the target environment.