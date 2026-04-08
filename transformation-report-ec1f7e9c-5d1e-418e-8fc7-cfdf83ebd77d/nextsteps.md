# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages that may need to be updated.

## 3. Build the Solution

Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these can indicate compatibility issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (backslashes, drive letters)
- `AppDomain` usage, which has limited support
- `BinaryFormatter`, which is obsolete and disabled by default

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to identify any remaining incompatible API calls.

## 6. Validate Runtime Behavior

Run the application and exercise its core functionality manually or through integration tests. Pay attention to:

- Configuration loading (e.g., migration from `App.config`/`Web.config` to `appsettings.json`)
- Logging behavior
- Database connectivity if ADO.NET or an ORM is in use (given the project name `AdoCore`, this is likely relevant)

If the project uses ADO.NET directly, verify that the correct database provider NuGet package is referenced, for example:

```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.x.x" />
```

## 7. Publish the Application

Once validation is complete, publish the application for the target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

To produce a self-contained executable for a specific platform:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target.

## 8. Review Output Artifacts

Inspect the contents of the publish output directory to confirm all required files, assemblies, and configuration files are present before deploying to the target environment.