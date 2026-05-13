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

Review the output for any warnings that may indicate deprecated APIs or platform-specific code paths that could cause issues at runtime.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences in the new runtime or by test setup issues.

---

## 4. Check for Platform-Specific Code

Search the codebase for APIs that are Windows-specific and may not behave correctly on Linux or macOS. Common areas to check include:

- `Microsoft.Win32` registry access
- `System.Drawing` (requires `libgdiplus` on Linux or migration to an alternative)
- `System.Windows.Forms` or `System.Web` references
- P/Invoke calls targeting Windows DLLs

Use the .NET Upgrade Assistant or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to surface these automatically.

---

## 5. Review NuGet Package Compatibility

Ensure all NuGet dependencies reference versions that are compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions supporting the target TFM. Pay particular attention to packages that previously targeted `net45` or `netstandard1.x`, as some may have breaking changes in newer versions.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to identify any runtime issues that do not surface during compilation.

```bash
dotnet run --configuration Release
```

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for Linux x64
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.