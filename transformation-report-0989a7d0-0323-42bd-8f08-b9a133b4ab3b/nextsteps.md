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

Review the output for any warnings that may indicate deprecated APIs or compatibility issues that did not surface as hard errors.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and trace them back to API or behavioral differences between the old .NET Framework and the new .NET runtime.

---

## 4. Check for Windows-Specific API Usage

Even without build errors, certain APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer or review the code manually for usage of:

- `System.Windows.Forms` or `System.Drawing` (without the `-Windows` TFM suffix)
- `Microsoft.Win32` registry APIs
- COM interop or P/Invoke calls targeting Windows-only libraries
- `AppDomain` APIs with limited cross-platform support

If cross-platform support is a strict requirement, address any such usages before proceeding.

---

## 5. Review NuGet Package Compatibility

Inspect `AdoCore.csproj` for any NuGet packages that may have been carried over from the legacy project. Verify each package supports the new target framework:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better .NET compatibility.

---

## 6. Test on Target Platforms

If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, environment variable handling, and any platform-specific configuration loading.

---

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

**Framework-dependent (smaller output, requires .NET runtime installed):**
```bash
dotnet publish -c Release -f net8.0
```

**Self-contained (includes runtime, no external dependency):**
```bash
dotnet publish -c Release -f net8.0 --self-contained true -r linux-x64
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your deployment target (e.g., `win-x64`, `osx-x64`).

---

## 8. Validate Published Output

After publishing, run the output binary directly from the publish folder to confirm it operates correctly outside of the development environment:

```bash
cd ./bin/Release/net8.0/publish
dotnet AdoCore.dll
```

Or, for a self-contained executable:

```bash
./AdoCore
```

Confirm that all expected functionality works as intended before treating the migration as complete.