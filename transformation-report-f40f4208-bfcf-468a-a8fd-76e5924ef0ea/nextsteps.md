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

Ensure there are no warnings that could indicate runtime issues, such as platform compatibility warnings (`CA1416`).

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the framework migration.

---

## 4. Check for Windows-Specific API Usage

Even without build errors, certain APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet build --configuration Release /p:EnableNETAnalyzers=true
```

Pay particular attention to any usage of:
- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- COM interop or P/Invoke calls targeting Windows-only libraries
- `System.Security.Permissions` types that have been stripped or made no-ops

---

## 5. Validate NuGet Package Compatibility

Review all NuGet dependencies and confirm they support the target framework. Run the following to check for any outdated or incompatible packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Replace any packages that do not have a compatible version with supported alternatives.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime-only platform issues:

```bash
dotnet run --configuration Release
```

Test all major code paths, particularly those involving file I/O, networking, or any areas that previously relied on Windows-specific behavior.

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Common runtime identifiers include `win-x64`, `linux-x64`, and `osx-x64`. Adjust as needed for your deployment target.

---

## 8. Review Configuration and Environment Variables

If the application previously relied on `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as `ConfigurationManager` behavior differs in .NET compared to .NET Framework.