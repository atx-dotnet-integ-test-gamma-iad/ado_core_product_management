# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, such as platform-specific API usage.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET.

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the build output for any `CA1416` warnings, which indicate APIs that are only supported on specific platforms (e.g., Windows). If such APIs are present and cross-platform support is required, they will need to be replaced or conditionally compiled.

You can also run the following to surface compatibility issues:

```bash
dotnet build --configuration Release /p:EnableNETAnalyzers=true
```

## 5. Review NuGet Package Compatibility

Confirm that all NuGet dependencies support the target framework. Open the `.csproj` file and check each `<PackageReference>`. You can verify compatibility on [nuget.org](https://www.nuget.org) or by inspecting the package's supported frameworks.

If any packages do not support the new TFM, look for updated versions or alternative packages.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended platform (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and any OS-specific behavior in the code.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate RID for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm the expected binaries and configuration files are present. Run the published output directly to confirm it executes correctly outside of the development environment.