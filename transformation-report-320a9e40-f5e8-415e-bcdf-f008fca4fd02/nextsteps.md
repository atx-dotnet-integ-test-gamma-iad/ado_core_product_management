# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removes certain APIs that were available in .NET Framework. Run the .NET Upgrade Assistant compatibility analyzer or the Platform Compatibility Analyzer to surface any runtime-level API issues that do not appear as build errors:

```bash
dotnet tool install -g dotnet-upgrade-assistant
dotnet-upgrade-assistant analyze
```

Pay particular attention to:
- `System.Web` usages
- Windows-specific registry or COM interop calls
- `AppDomain` APIs with limited support
- `BinaryFormatter` which is disabled by default in modern .NET

## 5. Review NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure each package supports your target framework. Check [nuget.org](https://www.nuget.org) for compatibility and update packages where necessary:

```bash
dotnet list package --outdated
```

## 6. Validate Runtime Behavior

Run the application locally and exercise its primary workflows. Check for:
- Correct file path handling (Linux/macOS use `/` as a separator)
- Case-sensitive file system behavior on Linux
- Environment-specific configuration loading (e.g., `appsettings.json` vs. legacy `app.config`)

## 7. Review Configuration Migration

If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, and that `Microsoft.Extensions.Configuration` is being used to read them.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) for your target environment.

## 9. Verify Output on Target Environment

Copy the published output to the target machine and run the executable directly to confirm it operates correctly outside of the development environment. Check application logs for any errors that only surface at runtime.