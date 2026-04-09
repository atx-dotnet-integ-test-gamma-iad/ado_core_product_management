# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues with NuGet packages or APIs that may have been replaced by cross-platform equivalents.

## 3. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with the target framework. You can inspect this by running:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or serialization behavior).

## 5. Check for Platform-Specific API Usage

Review the source code for any APIs that were Windows-specific in .NET Framework and may behave differently or be unavailable on cross-platform .NET. Common areas to check include:

- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client/server code
- `System.Drawing` (replaced by `System.Drawing.Common` with platform restrictions)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining platform-specific calls.

## 6. Validate ADO.NET / Database Connectivity

Since the project is named `AdoCore`, verify that database connections function correctly under the new runtime:

- Confirm the correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of the legacy `System.Data.SqlClient` where applicable).
- Run integration tests or manual connection tests against your target database to confirm queries, transactions, and connection pooling behave as expected.

## 7. Validate Configuration

If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables as appropriate for .NET. Verify that connection strings and other settings are correctly read at runtime.

## 8. Publish the Application

Once testing is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required runtime files and dependencies are present. If targeting a self-contained deployment, add the appropriate runtime identifier:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).