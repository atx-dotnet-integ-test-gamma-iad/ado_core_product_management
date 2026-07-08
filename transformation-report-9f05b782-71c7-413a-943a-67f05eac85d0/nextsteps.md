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

Review the code for any usage of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Microsoft provides a compatibility analyzer that can help:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Address any diagnostics raised by the analyzer.

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether failures are due to behavioral differences between .NET Framework and cross-platform .NET.

## 6. Validate Platform-Specific Behavior

Since this project involves ADO (ActiveX Data Objects or Azure DevOps), confirm the following depending on context:

- **If ADO refers to data access (e.g., `System.Data`):** Verify that all database connection strings, providers, and drivers (e.g., SQL Server, ODBC) are available and functional on the target platform.
- **If ADO refers to Azure DevOps client libraries:** Confirm that the Azure DevOps .NET client library packages are the current cross-platform compatible versions from NuGet.

## 7. Test on Target Operating Systems

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, environment variable access, and any Windows-specific registry or COM interop calls that may not function on non-Windows platforms.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the output in the `publish` folder before deploying to the target environment.