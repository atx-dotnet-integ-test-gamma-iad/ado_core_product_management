# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may have been replaced during the transformation (e.g., `System.Data.SqlClient` replaced by `Microsoft.Data.SqlClient`).

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the output for any warnings that, while not blocking the build, may indicate runtime issues.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite:

```bash
dotnet test --configuration Release
```

Confirm all previously passing tests continue to pass. Investigate any failures, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform equivalents.

## 5. Validate Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Data` and ADO.NET provider usage (confirm the correct database driver package is referenced)
- `System.Configuration` (replaced by `Microsoft.Extensions.Configuration`)
- `System.Web` (not available in cross-platform .NET)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or COM components

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 6. Run the Application

Execute the application directly to validate runtime behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any database connectivity logic given the ADO-related naming of the project.

## 7. Publish the Application

Once runtime validation is complete, publish the application for your target environment.

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target.

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm the expected binaries and configuration files are present. Run the published output directly to perform a final validation before deploying to the target environment.