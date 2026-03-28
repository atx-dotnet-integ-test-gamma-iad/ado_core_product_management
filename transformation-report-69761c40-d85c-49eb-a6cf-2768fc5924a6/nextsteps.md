# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Review NuGet Package Versions

Check all `<PackageReference>` entries in `AdoCore.csproj` and any other projects in the solution. Ensure that no packages are pinned to versions that target only .NET Framework. Use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, then rebuild to confirm nothing breaks.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, threading, or reflection behavior).

## 5. Check for Platform-Specific Code

Search the codebase for any APIs that were available in .NET Framework but are absent or behave differently in modern .NET. Common areas to review include:

- `System.Web` usage (not available in modern .NET)
- `AppDomain` APIs with limited support
- Windows Registry access (`Microsoft.Win32.Registry`)
- `BinaryFormatter` (disabled by default in .NET 5+)
- COM interop or P/Invoke calls targeting Windows-specific libraries

If any of these are present, determine whether a cross-platform alternative exists or whether the project should be marked as Windows-only using:

```xml
<RuntimeIdentifier>win-x64</RuntimeIdentifier>
```

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime failures that would not appear at build time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier and configuration:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Adjust `--runtime` to match your deployment target (e.g., `linux-x64`, `osx-x64`). Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Verify Published Output

Navigate to the publish output directory (typically `bin/Release/{tfm}/{rid}/publish/`) and confirm all expected files are present, including configuration files, static assets, and dependencies.