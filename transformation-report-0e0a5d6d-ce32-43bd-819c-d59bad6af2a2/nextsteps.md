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

Verify that no warnings or errors appear in the output, particularly any that reference platform-specific APIs or deprecated packages.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to confirm existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

---

## 4. Check for Platform-Specific API Usage

Even without build errors, certain APIs may behave differently or throw at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any analyzer warnings related to `PlatformNotSupportedException` or platform guards.

---

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and inspect all `<PackageReference>` entries. Confirm that each package supports the target framework. You can verify this on [nuget.org](https://www.nuget.org) or by checking the package's listed supported frameworks. Replace any packages that only support .NET Framework with their cross-platform equivalents.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to identify any runtime issues that do not surface during compilation:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators
- Registry access (not available on Linux/macOS)
- Windows-specific libraries such as `System.Drawing.Common`

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for Linux x64
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory before deploying to the target environment.