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

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Review any usages of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available in cross-platform .NET)
- `AppDomain` usage
- Windows Registry access (`Microsoft.Win32.Registry`)
- `ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)

## 5. Run Existing Tests

If there are test projects in the solution, execute them to validate runtime behavior:

```bash
dotnet test --configuration Release
```

Review any failing tests to determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET.

## 6. Validate on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended operating system (Windows, Linux, macOS) if applicable:

```bash
dotnet run --configuration Release
```

Pay attention to any platform-specific runtime exceptions, particularly around file paths, line endings, or OS-level APIs.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your target runtime identifier (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Review Output Artifacts

After publishing, verify the contents of the `publish` output directory to confirm all required assemblies, configuration files, and assets are present before deploying to the target environment.