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

Review the output for any warnings that may indicate deprecated APIs or platform-specific code paths that could cause runtime issues even though they compile cleanly.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may point to behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, encoding defaults, or threading behavior).

---

## 4. Check for Platform-Specific Code

Search the codebase for APIs that are known to behave differently or be unavailable on non-Windows platforms:

- `Microsoft.Win32` registry access
- `System.Drawing` (requires `libgdiplus` on Linux/macOS or the `System.Drawing.Common` NuGet package with additional configuration)
- COM interop or P/Invoke calls targeting Windows-only libraries
- `AppDomain.CreateDomain` (not supported in .NET Core and later)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining platform dependencies.

---

## 5. Validate ADO.NET / Data Access Behavior

Since the project is named `AdoCore`, it likely involves data access. Verify the following:

- The correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` for SQL Server).
- Connection string formats are still valid.
- Any `DataSet`, `DataTable`, or `DataAdapter` usage functions as expected, as some serialization behaviors changed between .NET Framework and modern .NET.

Run integration tests or manual queries against a test database to confirm data access works correctly end to end.

---

## 6. Review NuGet Package Versions

Ensure all NuGet dependencies are up to date and compatible with the target framework:

```bash
dotnet list package --outdated
```

Update packages that have newer versions available, particularly any that previously targeted `net45`/`net472` and now have dedicated `netstandard2.0` or `net6.0`/`net8.0` builds.

---

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only platform compatibility issues that do not appear at compile time.

---

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent (requires .NET runtime on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.