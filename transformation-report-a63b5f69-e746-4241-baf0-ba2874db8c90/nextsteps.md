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

Review the output for any warnings that may indicate compatibility issues, even if the build succeeds.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by API differences between the legacy framework and the new target framework.

---

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may behave differently or throw at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usage of:
- `System.Windows.Forms` or `System.Drawing` (requires additional packages on Linux/macOS)
- `Microsoft.Win32` registry APIs
- P/Invoke calls to Windows-specific native libraries
- `AppDomain.GetCurrentThreadId()` or other obsolete members

---

## 5. Validate NuGet Package Compatibility

Check that all referenced NuGet packages support the new target framework. Open each `.csproj` and verify that package versions are not pinned to versions that only supported `net4x`. You can use:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide cross-platform support.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to identify any runtime-only failures that were not caught at compile time.

```bash
dotnet run --configuration Release
```

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish/linux-x64
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish/win-x64
```

Review the contents of the output directory to confirm all required files are present before deploying.