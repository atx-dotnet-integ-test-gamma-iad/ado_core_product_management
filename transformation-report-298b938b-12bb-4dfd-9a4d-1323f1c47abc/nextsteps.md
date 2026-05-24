# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility issues, deprecated APIs, or platform-specific code paths that were silently retained.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

---

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Search the codebase for common platform-specific concerns:

- **Registry access** (`Microsoft.Win32.Registry`)
- **Windows-only UI frameworks** (e.g., `System.Windows.Forms`, `System.Drawing.Common`)
- **COM interop** or `[DllImport]` calls targeting Windows-only DLLs
- **`AppDomain`** usage patterns that behave differently in .NET Core+

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to assist with this review.

---

## 5. Review NuGet Package Compatibility

Confirm that all NuGet packages referenced in `AdoCore.csproj` support the target framework. Open the `.csproj` file and cross-reference each `<PackageReference>` against [nuget.org](https://www.nuget.org) to verify TFM compatibility.

Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better cross-platform support.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (e.g., Linux, macOS) to surface any runtime issues that do not appear on Windows:

```bash
dotnet run --configuration Release
```

Pay attention to:
- File path separators (`\` vs `/`)
- Case-sensitive file systems (Linux)
- Environment variable differences

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent (requires .NET runtime installed on target)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Verify the contents of the `./publish` directory before deploying to the target environment.