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

Review the output for any warnings that could indicate runtime issues, even if the build succeeds.

## 3. Review Removed or Replaced APIs

Check the codebase for any use of APIs that were available in .NET Framework but have changed behavior in cross-platform .NET. Common areas to review include:

- `System.Configuration` (replaced by `Microsoft.Extensions.Configuration`)
- `System.Web` (not available in cross-platform .NET)
- Windows-specific registry or file path assumptions
- `AppDomain` usage
- Reflection APIs with behavioral differences

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify functional correctness:

```bash
dotnet test --configuration Release
```

Review any failing tests and address the underlying issues before proceeding.

## 5. Manual Functional Testing

If there is no automated test coverage, perform manual testing of the core functionality of `AdoCore`. Pay particular attention to:

- Database connection and query execution
- Any ADO.NET-specific operations such as `DataAdapter`, `DataSet`, or `DataReader` usage
- Connection string configuration, ensuring it is read from the new configuration system correctly

## 6. Check NuGet Package Compatibility

Verify that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with the target framework. You can inspect this with:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform .NET support.

## 7. Test on Target Platform

If the intent is to run on a non-Windows operating system, build and run the project on that platform explicitly to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (e.g., `win-x64`, `osx-x64`) based on your deployment target.

## 9. Verify Output Artifacts

After publishing, confirm the output directory contains the expected assemblies and configuration files, and that no .NET Framework-specific artifacts remain.