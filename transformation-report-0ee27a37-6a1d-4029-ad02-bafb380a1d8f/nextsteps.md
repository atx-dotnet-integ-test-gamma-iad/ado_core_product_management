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

Review the output for any warnings that may indicate deprecated APIs or platform-specific code paths that could cause runtime issues even if they do not produce build errors.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

---

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been silently replaced or may throw `PlatformNotSupportedException` at runtime on non-Windows systems. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of:
- `System.Web` namespaces
- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop
- `AppDomain.CreateDomain`
- WCF server-side components

---

## 5. Validate NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions available, particularly those that previously targeted only .NET Framework.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime-only platform issues:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separator differences (`\` vs `/`)
- Case sensitivity in file system access on Linux
- Environment variable handling differences

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for Linux x64
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory before deploying to your target environment.