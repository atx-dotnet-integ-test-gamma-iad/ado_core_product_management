# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been replaced with stubs or may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer or review the Microsoft API compatibility documentation for any APIs that were previously Windows-only, such as:

- `System.Drawing`
- `Microsoft.Win32.Registry`
- `System.Security.Permissions`
- COM interop or P/Invoke calls

Run the analyzer with:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

## 5. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended platform (Windows, Linux, macOS) to catch any runtime issues that do not surface during compilation.

```bash
dotnet run --configuration Release
```

## 6. Review NuGet Package Versions

Open the `.csproj` file and verify that all NuGet package references are pointing to versions that support your target framework. Outdated packages that targeted .NET Framework may have newer versions with cross-platform support.

```bash
dotnet list package --outdated
```

Update packages as appropriate:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Verify Output Artifacts

After publishing, confirm the output directory contains the expected binaries and that the application starts correctly from the published location before deploying to a production environment.