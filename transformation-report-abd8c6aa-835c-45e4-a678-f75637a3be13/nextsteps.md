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

Confirm there are no warnings that could indicate deprecated APIs or platform-specific code paths that may fail at runtime.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

---

## 4. Check for Platform-Specific API Usage

Even without build errors, certain APIs may compile but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer or review the code manually for usage of:

- `System.Windows.Forms` or `System.Web`
- `Microsoft.Win32` registry access
- COM interop or P/Invoke calls targeting Windows-only libraries
- `AppDomain` APIs that have limited support in modern .NET

You can also run the following command to surface platform compatibility warnings:

```bash
dotnet build --configuration Release /p:EnableNETAnalyzers=true
```

---

## 5. Validate NuGet Package Compatibility

Check that all NuGet dependencies support the target framework. Review the `packages.lock.json` or run:

```bash
dotnet list package --outdated
```

Replace any packages that do not support your target TFM with their modern equivalents.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues that do not appear during compilation.

```bash
dotnet run --configuration Release
```

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

**Framework-dependent (requires .NET runtime installed on host):**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate RID for your target environment (e.g., `win-x64`, `osx-x64`, `linux-arm64`).

---

## 8. Review Output Artifacts

After publishing, verify the contents of the output directory to ensure all expected assemblies, configuration files, and static assets are present before deploying to the target environment.