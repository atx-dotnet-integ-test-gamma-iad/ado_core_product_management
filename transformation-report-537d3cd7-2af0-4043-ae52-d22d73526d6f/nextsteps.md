# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore and Build the Solution

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, such as platform-specific API usage.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

---

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining Windows-specific API calls that may not function correctly on Linux or macOS:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Address any flagged APIs by replacing them with cross-platform alternatives or adding appropriate runtime platform guards using `RuntimeInformation.IsOSPlatform`.

---

## 5. Validate Runtime Behavior on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`/` vs `\`)
- Environment variable access
- Registry access (Windows-only, must be removed or guarded)
- COM interop or P/Invoke calls

---

## 6. Review NuGet Package Compatibility

Check that all NuGet dependencies support the target framework. Run the following to list any packages that may have compatibility concerns:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update packages where newer cross-platform compatible versions are available.

---

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your deployment target (e.g., `win-x64`, `osx-x64`, `linux-arm64`). A full list of RIDs is available in the [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).