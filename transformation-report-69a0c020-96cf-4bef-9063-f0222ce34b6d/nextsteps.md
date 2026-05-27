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

Check all `<PackageReference>` entries in `AdoCore.csproj` to confirm that the referenced packages are compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and modern .NET.

## 5. Check for Platform-Specific API Usage

Since this was a cross-platform migration, audit the codebase for any APIs that may only function correctly on Windows, such as:

- `System.Windows.Forms`
- `Microsoft.Win32` registry access
- COM interop
- Windows-specific file path assumptions

Use the .NET Upgrade Assistant compatibility analyzer or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify these automatically.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (e.g., Linux, macOS) to catch any platform-specific runtime issues that would not appear during a Windows build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Verify Output Artifacts

After publishing, confirm the output directory contains the expected binaries and that the application starts correctly in the target environment before promoting to production.