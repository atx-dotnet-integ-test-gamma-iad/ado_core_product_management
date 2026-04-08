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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were silently ignored during transformation.

## 3. Review NuGet Package Versions

Check that all NuGet packages referenced in `AdoCore.csproj` are targeting compatible versions for your chosen .NET version. You can inspect outdated packages with:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to confirm existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and the cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been carried over that behave differently or are unsupported on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any analyzer warnings that appear after adding this package and rebuild.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators
- Registry access (not available on Linux/macOS)
- Windows-specific authentication or security APIs

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

For a framework-dependent deployment:

```bash
dotnet publish -c Release -o ./publish
```

Review the contents of the `./publish` directory to confirm all expected files are present before deploying to the target environment.