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

Review the output for any warnings that may indicate compatibility issues, even if the build succeeds.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been used that are Windows-specific and will fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Rebuild and review any new analyzer warnings related to platform compatibility.

## 5. Review NuGet Package Versions

Open `AdoCore.csproj` and inspect all `<PackageReference>` entries. Ensure each package:

- Supports the target framework (e.g., `net8.0`)
- Is not pinned to an outdated version that predates cross-platform .NET support

Update packages where necessary:

```bash
dotnet list package --outdated
dotnet add package <PackageName> --version <NewVersion>
```

## 6. Validate Runtime Behavior on Target Platforms

Run the application on each platform you intend to support (Linux, macOS, Windows) to catch any runtime-only issues such as:

- File path separator differences (`\` vs `/`)
- Missing platform-specific dependencies
- Environment variable or configuration differences

```bash
dotnet run --configuration Release
```

## 7. Review Configuration and File I/O

Check any code that reads configuration files, writes to the file system, or references absolute paths. Replace Windows-specific path assumptions with `Path.Combine` and `Environment.GetFolderPath` where applicable.

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish/linux-x64
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish/win-x64
```

Review the contents of the output directory to confirm all required files are present before deploying to the target environment.