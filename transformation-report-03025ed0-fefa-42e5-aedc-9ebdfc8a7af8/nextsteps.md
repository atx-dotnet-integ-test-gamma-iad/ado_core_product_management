# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Check all `<PackageReference>` entries in `AdoCore.csproj` and any other projects in the solution. Ensure that all packages are targeting versions compatible with your chosen .NET target framework. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any outdated packages as appropriate.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and modern .NET.

## 5. Check for Platform-Specific API Usage

Since this was a cross-platform migration, audit the codebase for any remaining Windows-specific APIs (e.g., registry access, `System.Windows.Forms`, COM interop). You can use the .NET Compatibility Analyzer to assist:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Address any platform compatibility warnings that appear in the build output.

## 6. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay particular attention to:

- File I/O paths, as path separators differ between Windows and Linux/macOS.
- Configuration file loading (e.g., migration from `App.config` to `appsettings.json`).
- Any reflection-based code that may behave differently under modern .NET.

## 7. Publish the Application

Once validation is complete, publish the application using the `dotnet publish` command. For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).

## 8. Review Published Output

Inspect the output directory produced by `dotnet publish` to confirm all required assemblies, configuration files, and assets are present before deploying to the target environment.