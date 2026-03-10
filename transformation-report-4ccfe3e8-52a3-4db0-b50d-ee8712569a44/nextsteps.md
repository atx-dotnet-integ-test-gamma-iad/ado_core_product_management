# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or platform-specific code paths that could cause issues at runtime.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been silently replaced or may throw `PlatformNotSupportedException` at runtime on non-Windows systems. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any analyzer warnings related to platform compatibility.

## 5. Review NuGet Package Versions

Open the `.csproj` file and inspect all `<PackageReference>` entries. Ensure that each package targets a version compatible with your chosen .NET TFM. Packages that previously targeted .NET Framework may have newer versions with cross-platform support:

```bash
dotnet list package --outdated
```

Update packages where appropriate and re-run the build and tests.

## 6. Validate Runtime Behavior on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues not surfaced during the build:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators
- Registry access calls (not available on Linux/macOS)
- Windows-specific interop or COM dependencies

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that location before deploying to your target environment.