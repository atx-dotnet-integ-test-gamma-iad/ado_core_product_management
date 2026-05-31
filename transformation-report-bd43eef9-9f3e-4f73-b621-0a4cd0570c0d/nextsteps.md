# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Review any usages of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Pay particular attention to:

- `System.Data` and ADO.NET-related APIs (given the `AdoCore` project name)
- Any database provider packages (e.g., `System.Data.SqlClient` should be replaced with `Microsoft.Data.SqlClient`)
- `ConfigurationManager` usage, which requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET

## 5. Run Existing Tests

If the solution contains a test project, execute the tests to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether failures are due to behavioral differences between .NET Framework and cross-platform .NET.

## 6. Validate on Target Operating Systems

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific issues:

```bash
dotnet run --configuration Release
```

Pay attention to:

- File path separator differences (`\` vs `/`)
- Case sensitivity in file system operations on Linux/macOS
- Any P/Invoke or Windows-specific interop calls that may not function on non-Windows platforms

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (e.g., `win-x64`, `osx-x64`) as needed. Review the output in the `publish` folder before deploying to the target environment.